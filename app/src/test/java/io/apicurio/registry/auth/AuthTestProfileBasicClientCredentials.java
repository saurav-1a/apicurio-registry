package io.apicurio.registry.auth;

import io.apicurio.common.apps.config.Info;
import io.apicurio.registry.AbstractResourceTestBase;
import io.apicurio.registry.client.auth.VertXAuthFactory;
import io.apicurio.registry.model.GroupId;
import io.apicurio.registry.rest.client.RegistryClient;
import io.apicurio.registry.rest.client.models.ArtifactContent;
import io.apicurio.registry.rest.client.models.Rule;
import io.apicurio.registry.rest.client.models.RuleType;
import io.apicurio.registry.rules.validity.ValidityLevel;
import io.apicurio.registry.types.ArtifactType;
import io.apicurio.registry.utils.tests.ApicurioTestTags;
import io.apicurio.registry.utils.tests.AuthTestProfile;
import io.apicurio.registry.utils.tests.JWKSMockServer;
import io.apicurio.registry.utils.tests.TestUtils;
import io.kiota.http.vertx.VertXRequestAdapter;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

import static io.apicurio.registry.client.auth.VertXAuthFactory.buildOIDCWebClient;
import static io.apicurio.registry.client.auth.VertXAuthFactory.buildSimpleAuthWebClient;
import static org.junit.jupiter.api.Assertions.assertNotNull;

@QuarkusTest
@TestProfile(AuthTestProfile.class)
@Tag(ApicurioTestTags.SLOW)
public class AuthTestProfileBasicClientCredentials extends AbstractResourceTestBase {

    @ConfigProperty(name = "registry.auth.token.endpoint")
    @Info(category = "auth", description = "Auth token endpoint", availableSince = "2.1.0.Final")
    String authServerUrl;

    final String groupId = "authTestGroupId";

    @Override
    protected RegistryClient createRestClientV3() {
        var adapter = new VertXRequestAdapter(buildOIDCWebClient(authServerUrl, JWKSMockServer.ADMIN_CLIENT_ID, "test1"));
        adapter.setBaseUrl(registryV3ApiUrl);
        return new RegistryClient(adapter);
    }
    @Test
    public void testWrongCreds() throws Exception {
        var adapter = new VertXRequestAdapter(buildSimpleAuthWebClient(JWKSMockServer.WRONG_CREDS_CLIENT_ID, "test55"));
        adapter.setBaseUrl(registryV3ApiUrl);
        RegistryClient client = new RegistryClient(adapter);
        var exception = Assertions.assertThrows(Exception.class, () -> {
            client.groups().byGroupId(groupId).artifacts().get();
        });
        assertNotAuthorized(exception);
    }

    @Test
    public void testBasicAuthClientCredentials() throws Exception {
        var adapter = new VertXRequestAdapter(buildSimpleAuthWebClient(JWKSMockServer.ADMIN_CLIENT_ID, "test1"));
        adapter.setBaseUrl(registryV3ApiUrl);
        RegistryClient client = new RegistryClient(adapter);
        String artifactId = TestUtils.generateArtifactId();
        try {
            client.groups().byGroupId(GroupId.DEFAULT.getRawGroupIdWithDefaultString()).artifacts().get();
            ArtifactContent content = new ArtifactContent();
            content.setContent("{}");
            var res = client
                    .groups()
                    .byGroupId(groupId)
                    .artifacts()
                    .post(content, config -> {
                        config.headers.add("X-Registry-ArtifactType", ArtifactType.JSON);
                        config.headers.add("X-Registry-ArtifactId", artifactId);
                    });

            TestUtils.retry(() ->
                    client
                            .groups()
                            .byGroupId(groupId)
                            .artifacts()
                            .byArtifactId(artifactId)
                            .meta()
                            .get()
                            );
            assertNotNull(client.groups().byGroupId(groupId).artifacts().byArtifactId(artifactId).get());

            Rule ruleConfig = new Rule();
            ruleConfig.setType(RuleType.VALIDITY);
            ruleConfig.setConfig(ValidityLevel.NONE.name());

            client.groups().byGroupId(groupId).artifacts().byArtifactId(artifactId).rules().post(ruleConfig);
            client.admin().rules().post(ruleConfig);
        } finally {
            client.groups().byGroupId(groupId).artifacts().byArtifactId(artifactId).delete();
        }
    }

    @Test
    public void testNoCredentials() throws Exception {
        var adapter = new VertXRequestAdapter(VertXAuthFactory.defaultVertx);
        adapter.setBaseUrl(registryV3ApiUrl);
        RegistryClient client = new RegistryClient(adapter);
        var exception = Assertions.assertThrows(Exception.class, () -> {
            client.groups().byGroupId(groupId).artifacts().get();
        });
        assertNotAuthorized(exception);
    }
}
