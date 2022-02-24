/*
 * Copyright 2021 Red Hat
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package io.apicurio.registry.maven;

import io.apicurio.registry.rest.client.AdminClient;
import io.apicurio.registry.rest.client.AdminClientFactory;
import io.apicurio.registry.rest.client.RegistryClient;
import io.apicurio.registry.rest.client.RegistryClientFactory;
import io.apicurio.registry.utils.tests.ApicurioTestTags;
import io.apicurio.registry.utils.tests.AuthTestProfile;
import io.apicurio.registry.utils.tests.TestUtils;
import io.apicurio.rest.client.auth.Auth;
import io.apicurio.rest.client.auth.OidcAuth;
import io.apicurio.rest.client.auth.exception.AuthErrorHandler;
import io.apicurio.rest.client.spi.ApicurioHttpClient;
import io.apicurio.rest.client.spi.ApicurioHttpClientFactory;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugin.MojoFailureException;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.util.Collections;

@QuarkusTest
@TestProfile(AuthTestProfile.class)
@Tag(ApicurioTestTags.DOCKER)
public class MojoAuthTest extends RegistryMojoTestBase {

    @ConfigProperty(name = "registry.auth.token.endpoint")
    String authServerUrlConfigured;

    @ConfigProperty(name = "quarkus.oidc.tenant-enabled")
    Boolean authEnabled;

    String adminClientId = "registry-api";

    String clientSecret = "test1";

    String testUsername = "sr-test-user";
    String testPassword = "sr-test-password";

    ApicurioHttpClient httpClient;

    private RegistryClient createClient(Auth auth) {
        return RegistryClientFactory.create(registryV2ApiUrl, Collections.emptyMap(), auth);
    }

    private AdminClient createAdminClient(Auth auth) {
        return AdminClientFactory.create(registryV2ApiUrl, Collections.emptyMap(), auth);
    }

    /**
     * @see io.apicurio.registry.AbstractResourceTestBase#createRestClientV2()
     */
    @Override
    protected RegistryClient createRestClientV2() {
        httpClient = ApicurioHttpClientFactory.create(authServerUrlConfigured, new AuthErrorHandler());
        System.out.println("Auth is " + authEnabled);
        Auth auth = new OidcAuth(httpClient, adminClientId, "test1");
        return this.createClient(auth);
    }

    @Override
    protected AdminClient createAdminClientV2() {
        httpClient = ApicurioHttpClientFactory.create(authServerUrlConfigured, new AuthErrorHandler());
        System.out.println("Auth is " + authEnabled);
        Auth auth = new OidcAuth(httpClient, adminClientId, "test1");
        return this.createAdminClient(auth);
    }

    @Test
    public void testRegister() throws IOException, MojoFailureException, MojoExecutionException {
        System.out.println("Auth is " + authEnabled);

        RegisterRegistryMojo registerRegistryMojo = new RegisterRegistryMojo();
        registerRegistryMojo.setRegistryUrl(TestUtils.getRegistryV2ApiUrl());
        registerRegistryMojo.setAuthServerUrl(authServerUrlConfigured);
        registerRegistryMojo.setClientId(adminClientId);
        registerRegistryMojo.setClientSecret(clientSecret);

        super.testRegister(registerRegistryMojo, "testRegister");
    }

    @Test
    public void testBasicAuth() throws IOException, MojoFailureException, MojoExecutionException {
        System.out.println("Auth is " + authEnabled);

        RegisterRegistryMojo registerRegistryMojo = new RegisterRegistryMojo();
        registerRegistryMojo.setClient(null);

        registerRegistryMojo.setRegistryUrl(TestUtils.getRegistryV2ApiUrl());
        registerRegistryMojo.setUsername(testUsername);
        registerRegistryMojo.setPassword(testPassword);

        super.testRegister(registerRegistryMojo, "testBasicAuth");
    }
}
