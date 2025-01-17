package co.worklytics.psoxy.gateway.impl.oauth;

import co.worklytics.psoxy.PsoxyModule;
import co.worklytics.psoxy.SourceAuthModule;
import co.worklytics.test.MockModules;
import com.google.api.client.http.HttpHeaders;
import dagger.Component;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import javax.inject.Inject;
import javax.inject.Singleton;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;

class AccountCredentialsGrantTokenRequestPayloadBuilderTest {

    @Inject
    AccountCredentialsGrantTokenRequestPayloadBuilder payloadBuilder;

    @Singleton
    @Component(modules = {
        PsoxyModule.class,
        SourceAuthModule.class,
        MockModules.ForConfigService.class,
    })
    public interface Container {
        void inject(AccountCredentialsGrantTokenRequestPayloadBuilderTest test);
    }

    @BeforeEach
    public void setup() {
        AccountCredentialsGrantTokenRequestPayloadBuilderTest.Container container =
            DaggerAccountCredentialsGrantTokenRequestPayloadBuilderTest_Container.create();
        container.inject(this);
    }

    @Test
    void addHeaders() {
        when(payloadBuilder.config
            .getConfigPropertyOrError(AccountCredentialsGrantTokenRequestPayloadBuilder.ConfigProperty.CLIENT_ID))
            .thenReturn("client");
        when(payloadBuilder.config
            .getConfigPropertyOrError(AccountCredentialsGrantTokenRequestPayloadBuilder.ConfigProperty.CLIENT_SECRET))
            .thenReturn("secret");

        HttpHeaders headers = new HttpHeaders();
        payloadBuilder.addHeaders(headers);

        assertEquals("Basic Y2xpZW50OnNlY3JldA==", headers.getAuthorization());
    }
}
