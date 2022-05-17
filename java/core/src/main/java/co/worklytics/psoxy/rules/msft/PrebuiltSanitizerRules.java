package co.worklytics.psoxy.rules.msft;

import co.worklytics.psoxy.Rules;
import com.google.common.collect.ImmutableMap;

import java.util.Map;

public class PrebuiltSanitizerRules {

    static final Rules DIRECTORY =  Rules.builder()
        //GENERAL stuff
        .allowedEndpointRegex("^/(v1.0|beta)/(groups|users)/?[^/]*")
        .allowedEndpointRegex("^/(v1.0|beta)/(groups|users)\\?.*")
        .allowedEndpointRegex("^/(v1.0|beta)/groups/[^/]*/members[^/]*")
        .redaction(Rules.Rule.builder()
            // https://docs.microsoft.com/en-us/graph/api/user-list?view=graph-rest-1.0&tabs=http
            .relativeUrlRegex("^/(v1.0|beta)/users.*")
            .jsonPath("$..displayName")
            .jsonPath("$..employeeId")
            .jsonPath("$..aboutMe")
            .jsonPath("$..mySite")
            .jsonPath("$..preferredName")
            .jsonPath("$..givenName")
            .jsonPath("$..surname")
            .jsonPath("$..mailNickname") //get the actual mail
            .jsonPath("$..proxyAddresses")
            .jsonPath("$..faxNumber")
            .jsonPath("$..mobilePhone")
            .jsonPath("$..businessPhones[*]")
            .build())
        .pseudonymization(Rules.Rule.builder()
            // https://docs.microsoft.com/en-us/graph/api/user-list?view=graph-rest-1.0&tabs=http
            .relativeUrlRegex("^/(v1.0|beta)/users.*")
            .jsonPath("$..userPrincipalName")
            .jsonPath("$..imAddresses[*]")
            .jsonPath("$..mail")
            .jsonPath("$..otherMails[*]")
            .build()
        )
        .redaction(Rules.Rule.builder()
            .relativeUrlRegex("^/(v1.0|beta)/groups.*")
            .jsonPath("$..owners")
            .jsonPath("$..rejectedSenders")
            .jsonPath("$..acceptedSenders")
            .jsonPath("$..members")
            .jsonPath("$..membersWithLicenseErrors")
            .build())
        .redaction(Rules.Rule.builder()
            .relativeUrlRegex("^/(v1.0|beta)/groups/[^/]*/members.*")
            .jsonPath("$..displayName")
            .jsonPath("$..employeeId")
            .jsonPath("$..aboutMe")
            .jsonPath("$..mySite")
            .jsonPath("$..preferredName")
            .jsonPath("$..givenName")
            .jsonPath("$..surname")
            .jsonPath("$..mailNickname") //get the actual mail
            .jsonPath("$..proxyAddresses")
            .jsonPath("$..faxNumber")
            .jsonPath("$..mobilePhone")
            .jsonPath("$..businessPhones[*]")
            .build())
        .pseudonymization(Rules.Rule.builder()
            .relativeUrlRegex("^/(v1.0|beta)/groups/[^/]*/members.*")
            .jsonPath("$..userPrincipalName")
            .jsonPath("$..imAddresses[*]")
            .jsonPath("$..mail")
            .jsonPath("$..otherMails[*]")
            .build()
        )
        .build();

    static final Rules OUTLOOK_MAIL = DIRECTORY.compose(Rules.builder()
        .allowedEndpointRegex("^/(v1.0|beta)/users/[^/]*/messages/[^/]*")
        .allowedEndpointRegex("^/(v1.0|beta)/users/[^/]*/mailFolders(/SentItems|\\('SentItems'\\))/messages.*")
        .allowedEndpointRegex("^/(v1.0|beta)/users/[^/]*/mailboxSettings")
        .pseudonymization(Rules.Rule.builder()
            .relativeUrlRegex("^/(v1.0|beta)/users/[^/]*/mailFolders(/SentItems|\\('SentItems'\\))/messages.*")
            .jsonPath("$..emailAddress.address")
            .build())
        .redaction(Rules.Rule.builder()
            .relativeUrlRegex("^/(v1.0|beta)/users/[^/]*/mailFolders(/SentItems|\\('SentItems'\\))/messages.*")
            .jsonPath("$..subject")
            .jsonPath("$..body")
            .jsonPath("$..bodyPreview")
            .jsonPath("$..emailAddress.name")
            .jsonPath("$..extensions")
            .jsonPath("$..multiValueExtendedProperties")
            .jsonPath("$..singleValueExtendedProperties")
            .jsonPath("$..internetMessageHeaders") //values that we care about generally parsed to other fields
            .build())
        .pseudonymization(Rules.Rule.builder()
            .relativeUrlRegex("^/(v1.0|beta)/users/[^/]*/messages/[^/]*")
            .jsonPath("$..emailAddress.address")
            .build())
        .redaction(Rules.Rule.builder()
            .relativeUrlRegex("^/(v1.0|beta)/users/[^/]*/messages/[^/]*")
            .jsonPath("$..subject")
            .jsonPath("$..body")
            .jsonPath("$..bodyPreview")
            .jsonPath("$..emailAddress.name")
            .jsonPath("$..extensions")
            .jsonPath("$..multiValueExtendedProperties")
            .jsonPath("$..singleValueExtendedProperties")
            .jsonPath("$..internetMessageHeaders") //values that we care about generally parsed to other fields
            .build())
        .build());

    static final Rules OUTLOOK_CALENDAR = DIRECTORY.compose(Rules.builder()
        .allowedEndpointRegex("^/(v1.0|beta)/users/[^/]*/(calendars/[^/]*/)?events.*")
        .allowedEndpointRegex("^/(v1.0|beta)/users/[^/]*/mailboxSettings")
        .allowedEndpointRegex("^/beta/users/[^/]*/calendar/calendarView(?)[^/]*")
        .pseudonymization(Rules.Rule.builder()
            .relativeUrlRegex("^/(v1.0|beta)/users/[^/]*/calendar/calendarView(?)[^/]*")
            .jsonPath("$..emailAddress.address")
            .build())
        .redaction(Rules.Rule.builder()
            .relativeUrlRegex("^/(v1.0|beta)/users/[^/]*/calendar/calendarView(?)[^/]*")
            .jsonPath("$..subject")
            .jsonPath("$..body")
            .jsonPath("$..bodyPreview")
            .jsonPath("$..emailAddress.name")
            .jsonPath("$..extensions")
            .jsonPath("$..multiValueExtendedProperties")
            .jsonPath("$..singleValueExtendedProperties")
            .jsonPath("$..location.uniqueId")
            .jsonPath("$..locations[*].uniqueId")
            .build())
        .pseudonymization(Rules.Rule.builder()
            .relativeUrlRegex("^/(v1.0|beta)/users/[^/]*/(calendars/[^/]*/)?events.*")
            .jsonPath("$..emailAddress.address")
            .build())
        .redaction(Rules.Rule.builder()
            .relativeUrlRegex("^/(v1.0|beta)/users/[^/]*/(calendars/[^/]*/)?events.*")
            .jsonPath("$..subject")
            .jsonPath("$..body")
            .jsonPath("$..bodyPreview")
            .jsonPath("$..emailAddress.name")
            .jsonPath("$..extensions")
            .jsonPath("$..multiValueExtendedProperties")
            .jsonPath("$..singleValueExtendedProperties")
            .jsonPath("$..location.uniqueId")
            .jsonPath("$..locations[*].uniqueId")
            .build())
        .build());


    public static final Map<String,? extends Rules> MSFT_DEFAULT_RULES_MAP =
        ImmutableMap.<String, Rules>builder()
            .put("azure-ad", DIRECTORY)
            .put("outlook-cal", OUTLOOK_CALENDAR)
            .put("outlook-mail", OUTLOOK_MAIL)
            .build();
}
