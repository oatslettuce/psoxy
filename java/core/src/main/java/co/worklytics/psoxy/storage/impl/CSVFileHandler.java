package co.worklytics.psoxy.storage.impl;

import co.worklytics.psoxy.PseudonymizedIdentity;
import com.avaulta.gateway.pseudonyms.Pseudonym;
import com.avaulta.gateway.pseudonyms.PseudonymEncoder;
import com.avaulta.gateway.pseudonyms.impl.JsonPseudonymEncoder;
import com.avaulta.gateway.pseudonyms.impl.UrlSafeTokenPseudonymEncoder;
import com.avaulta.gateway.rules.ColumnarRules;
import co.worklytics.psoxy.Sanitizer;
import co.worklytics.psoxy.storage.FileHandler;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.common.base.Preconditions;
import com.google.common.collect.Sets;
import com.google.common.collect.Streams;
import lombok.NoArgsConstructor;
import lombok.NonNull;
import lombok.extern.java.Log;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVPrinter;
import org.apache.commons.lang3.StringUtils;

import javax.inject.Inject;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.util.*;
import java.util.function.BiFunction;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Handles a CSV file to apply the rules pseudonymize the content.
 * CSV should have the first row with headers and being separated with commas; content should be quoted
 * if include commas or quotes inside.
 */
@Log
@NoArgsConstructor(onConstructor_ = @Inject)
public class CSVFileHandler implements FileHandler {

    @Inject
    ObjectMapper objectMapper;


    @Override
    public byte[] handle(@NonNull InputStreamReader reader, @NonNull Sanitizer sanitizer) throws IOException {

        Sanitizer.ConfigurationOptions configurationOptions = sanitizer.getConfigurationOptions();

        ColumnarRules rules = (ColumnarRules) configurationOptions.getRules();

        CSVParser records = CSVFormat
                .DEFAULT
                .withDelimiter(rules.getDelimiter())
                .withFirstRecordAsHeader()
                .withIgnoreHeaderCase()
                .withTrim()
                .parse(reader);

        Preconditions.checkArgument(records.getHeaderMap() != null, "Failed to parse header from file");

        Set<String> columnsToRedact = asSetWithCaseInsensitiveComparator(rules.getColumnsToRedact());

        Set<String> columnsToPseudonymize = asSetWithCaseInsensitiveComparator(rules.getColumnsToPseudonymize());

        Optional<Set<String>> columnsToInclude =
            Optional.ofNullable(rules.getColumnsToInclude())
                .map(this::asSetWithCaseInsensitiveComparator);

        final Map<String, String> columnsToRename = ((ColumnarRules) configurationOptions.getRules())
            .getColumnsToRename()
            .entrySet().stream()
            .collect(Collectors.toMap(
                entry -> entry.getKey().trim(),
                entry -> entry.getValue().trim(),
                (a, b) -> a,
                () -> new TreeMap<>(String.CASE_INSENSITIVE_ORDER)));

        final Map<String, String> columnsToDuplicate = ((ColumnarRules) configurationOptions.getRules())
            .getColumnsToDuplicate()
            .entrySet().stream()
            .collect(Collectors.toMap(
                entry -> entry.getKey().trim(),
                entry -> entry.getValue().trim(),
                (a, b) -> a,
                () -> new TreeMap<>(String.CASE_INSENSITIVE_ORDER)));


        // headers respecting insertion order
        // when constructing the parser with ignore header case the keySet may not return values in
        // order. header map is <key, position>, order by position first, then construct the key set
        Set<String> headers = records.getHeaderMap()
                .entrySet()
                .stream()
                .sorted(Comparator.comparingInt(Map.Entry::getValue))
                .filter(entry -> !columnsToRedact.contains(entry.getKey()))
                .filter(entry -> columnsToInclude.map(includeSet -> includeSet.contains(entry.getKey())).orElse(true))
                .map(Map.Entry::getKey)
                .collect(Collectors.toCollection(LinkedHashSet::new));

        // case-insensitive headers
        Set<String> headersCI = new TreeSet<>(String.CASE_INSENSITIVE_ORDER);
        headersCI.addAll(headers);

        // check if there are columns that are configured to be pseudonymized but are not present in
        // the file
        // NOTE: used to error, but now just logs. use case is if someone is trying to be defensive
        // by pseudonymizing IF column should happen to exist
        Set<String> outputColumnsCI = new TreeSet<>(String.CASE_INSENSITIVE_ORDER);
        outputColumnsCI.addAll(applyReplacements(headersCI, columnsToRename));
        Sets.SetView<String> missingColumnsToPseudonymize =
            Sets.difference(columnsToPseudonymize, outputColumnsCI);
        if (!missingColumnsToPseudonymize.isEmpty()) {
            log.info(String.format("Columns to pseudonymize (%s) missing from set found in file (%s)",
                "\"" + String.join("\",\"", missingColumnsToPseudonymize) + "\"",
                "\"" + String.join("\",\"", headersCI) + "\""));
        }


        List<String> columnNamesForOutputFile = Streams.concat(
            applyReplacements(headers, columnsToRename).stream(),
            columnsToDuplicate.values().stream())
            .collect(Collectors.toList());


        BiFunction<String, String, String> applyPseudonymizationIfAny = (outputColumnName, value) -> {
            if (columnsToPseudonymize.contains(outputColumnName)) {
                if (StringUtils.isNotBlank(value)) {
                    try {
                        PseudonymizedIdentity identity = sanitizer.pseudonymize(value);

                        if (identity == null) {
                            return null;
                        } else if (rules.getPseudonymFormat() == PseudonymEncoder.Implementations.URL_SAFE_TOKEN) {
                            return identity.getHash();
                        } else {
                            //JSON
                            return objectMapper.writeValueAsString(identity);
                        }
                    } catch (JsonProcessingException e) {
                        throw new RuntimeException(e);
                    }
                }
            }
            return value;
        };


        try(ByteArrayOutputStream baos = new ByteArrayOutputStream(1024);
            PrintWriter printWriter = new PrintWriter(baos);
            CSVPrinter printer = new CSVPrinter(printWriter, CSVFormat.DEFAULT
                .withHeader(columnNamesForOutputFile.toArray(new String[0])))
            ) {

            records.forEach(row -> {
                Stream<Object> sanitized =
                        headers.stream() // only iterate on allowed headers
                        .map(column ->
                                applyPseudonymizationIfAny.apply(
                                    columnsToRename.getOrDefault(column, column),
                                    row.get(column))
                        );

                sanitized = Streams.concat(sanitized, columnsToDuplicate.entrySet().stream()
                    .map(entry ->
                        applyPseudonymizationIfAny.apply(entry.getValue(), row.get(entry.getKey()))));

                try {
                    printer.printRecord(sanitized.collect(Collectors.toList()));
                } catch (Throwable e) {
                    throw new RuntimeException("Failed to write row", e);
                }
            });

            printWriter.flush();

            return baos.toByteArray();
        }
    }


    List<String> applyReplacements(Collection<String> original, final Map<String, String> replacements) {
        return original.stream()
            .map(value -> replacements.getOrDefault(value, value))
            .collect(Collectors.toList());
    }


    Set<String> asSetWithCaseInsensitiveComparator(Collection<String> set) {
        return set.stream()
            .map(String::trim)
            .collect(Collectors.toCollection(() -> new TreeSet<>(String.CASE_INSENSITIVE_ORDER)));
    }

}
