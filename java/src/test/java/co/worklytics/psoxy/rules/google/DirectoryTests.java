package co.worklytics.psoxy.rules.google;

import co.worklytics.psoxy.Rules;
import co.worklytics.psoxy.rules.RulesBaseTestCase;
import com.google.api.client.http.GenericUrl;
import lombok.Getter;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.Collection;

import static org.junit.jupiter.api.Assertions.assertTrue;

public class DirectoryTests extends RulesBaseTestCase {

    @Getter
    final Rules rulesUnderTest = PrebuiltSanitizerRules.GDIRECTORY;

    @Getter
    final String exampleDirectoryPath = "api-response-examples/g-workspace/directory";

    @Test
    void user() {
        String jsonString = asJson("user.json");

        //verify precondition that example actually contains something we need to pseudonymize
        assertTrue(jsonString.contains("alice@worklytics.co"));

        Collection<String> PII = Arrays.asList(
            "alice@worklytics.co",
            "alice.example@gmail.com"
        );
        assertNotSanitized(jsonString, PII);

        String sanitized =
            sanitizer.sanitize(new GenericUrl("https://admin.googleapis.com/admin/directory/v1/users/123213"), jsonString);

        assertPseudonymized(sanitized, Arrays.asList("alice@worklytics.co"));
        assertRedacted(sanitized, Arrays.asList("alice.example@gmail.com"));
    }

    @Test
    void users() {
        String jsonString = asJson("users.json");

        //verify precondition that example actually contains something we need to pseudonymize
        Collection<String> PII = Arrays.asList(
            "alice@worklytics.co",
            "bob@worklytics.co",
            "alice.example@gmail.com"
        );
        assertNotSanitized(jsonString, PII);

        String sanitized =
            sanitizer.sanitize(new GenericUrl("https://admin.googleapis.com/admin/directory/v1/users?customer=my_customer"), jsonString);

        assertPseudonymized(sanitized, Arrays.asList("alice@worklytics.co", "bob@worklytics.co"));
        assertRedacted(sanitized, Arrays.asList("alice.example@gmail.com"));
    }
}