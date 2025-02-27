package io.apicurio.registry.noprofile.content;

import io.apicurio.registry.AbstractResourceTestBase;
import io.apicurio.registry.content.ContentHandle;
import io.apicurio.registry.content.extract.ContentExtractor;
import io.apicurio.registry.content.extract.ExtractedMetaData;
import io.apicurio.registry.rest.client.models.ArtifactContent;
import io.apicurio.registry.rest.client.models.ArtifactMetaData;
import io.apicurio.registry.types.ArtifactType;
import io.apicurio.registry.types.provider.ArtifactTypeUtilProvider;
import io.apicurio.registry.types.provider.ArtifactTypeUtilProviderFactory;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

@QuarkusTest
public class ContentExtractorTest extends AbstractResourceTestBase {

    private static final String avroFormat = "{\r\n" +
                                             "     \"type\": \"record\",\r\n" +
                                             "     \"namespace\": \"com.example\",\r\n" +
                                             "     \"name\": \"%s\",\r\n" +
                                             "     \"fields\": [\r\n" +
                                             "       { \"name\": \"first\", \"type\": \"string\" },\r\n" +
                                             "       { \"name\": \"middle\", \"type\": \"string\" },\r\n" +
                                             "       { \"name\": \"last\", \"type\": \"string\" }\r\n" +
                                             "     ]\r\n" +
                                             "} ";

    private static final String jsonFormat = "{\r\n" +
                                             "   \"$schema\": \"http://json-schema.org/draft-04/schema#\",\r\n" +
                                             "   \"title\": \"%s\",\r\n" +
                                             "   \"description\": \"%s\",\r\n" +
                                             "   \"type\": \"object\",\r\n" +
                                             "    \r\n" +
                                             "   \"properties\": {\r\n" +
                                             "    \r\n" +
                                             "      \"id\": {\r\n" +
                                             "         \"description\": \"The unique identifier for a product\",\r\n" +
                                             "         \"type\": \"integer\"\r\n" +
                                             "      },\r\n" +
                                             "        \r\n" +
                                             "      \"name\": {\r\n" +
                                             "         \"description\": \"Name of the product\",\r\n" +
                                             "         \"type\": \"string\"\r\n" +
                                             "      },\r\n" +
                                             "        \r\n" +
                                             "      \"price\": {\r\n" +
                                             "         \"type\": \"number\",\r\n" +
                                             "         \"minimum\": 0,\r\n" +
                                             "         \"exclusiveMinimum\": true\r\n" +
                                             "      }\r\n" +
                                             "   },\r\n" +
                                             "    \r\n" +
                                             "   \"required\": [\"id\", \"name\", \"price\"]\r\n" +
                                             "}";

    private static final String openapiFormat = "{\r\n" +
            "    \"openapi\": \"3.0.2\",\r\n" +
            "    \"info\": {\r\n" +
            "        \"title\": \"%s\",\r\n" +
            "        \"version\": \"1.0.0\",\r\n" +
            "        \"description\": \"%s\"\r\n" +
            "    }\r\n" +
            "}";

    private static final String asyncapiFormat = "{\r\n" +
            "  \"asyncapi\" : \"2.0.0\",\r\n" +
            "  \"info\" : {\r\n" +
            "    \"title\": \"%s\",\r\n" +
            "    \"description\": \"%s\",\r\n" +
            "    \"version\": \"1.0.1\"\r\n" +
            "  }\r\n" +
            "}";

    private static final String wsdlFormat = "<?xml version=\"1.0\"?>\r\n" +
            "<definitions name=\"StockQuote\"\r\n" +
            "\r\n" +
            "targetNamespace=\"http://example.com/stockquote.wsdl\"\r\n" +
            "          xmlns:tns=\"http://example.com/stockquote.wsdl\"\r\n" +
            "          xmlns:xsd1=\"http://example.com/stockquote.xsd\"\r\n" +
            "          xmlns:soap=\"http://schemas.xmlsoap.org/wsdl/soap/\"\r\n" +
            "          xmlns=\"http://schemas.xmlsoap.org/wsdl/\">\r\n" +
            "\r\n" +
            "    <types>\r\n" +
            "       <schema targetNamespace=\"http://example.com/stockquote.xsd\"\r\n" +
            "              xmlns=\"http://www.w3.org/2000/10/XMLSchema\">\r\n" +
            "           <element name=\"TradePriceRequest\">\r\n" +
            "              <complexType>\r\n" +
            "                  <all>\r\n" +
            "                      <element name=\"tickerSymbol\" type=\"string\"/>\r\n" +
            "                  </all>\r\n" +
            "              </complexType>\r\n" +
            "           </element>\r\n" +
            "           <element name=\"TradePrice\">\r\n" +
            "              <complexType>\r\n" +
            "                  <all>\r\n" +
            "                      <element name=\"price\" type=\"float\"/>\r\n" +
            "                  </all>\r\n" +
            "              </complexType>\r\n" +
            "           </element>\r\n" +
            "       </schema>\r\n" +
            "    </types>\r\n" +
            "\r\n" +
            "</definitions>";

    private static final String xsdFormat = "<xsd:schema xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"\r\n" +
            "           xmlns:tns=\"http://tempuri.org/PurchaseOrderSchema.xsd\"\r\n" +
            "           targetNamespace=\"http://tempuri.org/PurchaseOrderSchema.xsd\"\r\n" +
            "           elementFormDefault=\"qualified\">\r\n" +
            " <xsd:element name=\"PurchaseOrder\" type=\"tns:PurchaseOrderType\"/>\r\n" +
            " <xsd:complexType name=\"PurchaseOrderType\">\r\n" +
            "  <xsd:sequence>\r\n" +
            "   <xsd:element name=\"ShipTo\" type=\"tns:USAddress\" maxOccurs=\"2\"/>\r\n" +
            "   <xsd:element name=\"BillTo\" type=\"tns:USAddress\"/>\r\n" +
            "  </xsd:sequence>\r\n" +
            "  <xsd:attribute name=\"OrderDate\" type=\"xsd:date\"/>\r\n" +
            " </xsd:complexType>\r\n" +
            "\r\n" +
            " <xsd:complexType name=\"USAddress\">\r\n" +
            "  <xsd:sequence>\r\n" +
            "   <xsd:element name=\"name\"   type=\"xsd:string\"/>\r\n" +
            "   <xsd:element name=\"street\" type=\"xsd:string\"/>\r\n" +
            "   <xsd:element name=\"city\"   type=\"xsd:string\"/>\r\n" +
            "   <xsd:element name=\"state\"  type=\"xsd:string\"/>\r\n" +
            "   <xsd:element name=\"zip\"    type=\"xsd:integer\"/>\r\n" +
            "  </xsd:sequence>\r\n" +
            "  <xsd:attribute name=\"country\" type=\"xsd:NMTOKEN\" fixed=\"US\"/>\r\n" +
            " </xsd:complexType>\r\n" +
            "</xsd:schema>";

    final String groupId = getClass().getSimpleName();

    @Inject
    ArtifactTypeUtilProviderFactory factory;

    @Test
    public void testAvro() {
        String name = "schema-" + generateArtifactId();
        String content = String.format(avroFormat, name);

        ArtifactTypeUtilProvider provider = factory.getArtifactTypeProvider(ArtifactType.AVRO);
        ContentExtractor extractor = provider.getContentExtractor();

        ExtractedMetaData emd = extractor.extract(ContentHandle.create(content));
        Assertions.assertTrue(extractor.isExtracted(emd));
        Assertions.assertEquals(name, emd.getName());
    }

    @Test
    public void testAvroClient() throws Exception {
        String artifactId = generateArtifactId();

        // Avro schema names can only have letters, digits, and _
        String name = "schema_" + System.currentTimeMillis();
        String content = String.format(avroFormat, name);

        ArtifactContent data = new ArtifactContent();
        data.setContent(content);
        ArtifactMetaData amd = clientV3.groups().byGroupId(groupId).artifacts().post(data, config -> {
            config.headers.add("X-Registry-ArtifactId", artifactId);
            config.headers.add("X-Registry-ArtifactType", ArtifactType.AVRO);
        });

        Assertions.assertEquals(name, amd.getName());

        // test update

        // Avro schema names can only have letters, digits, and _
        name = "schema_" + System.currentTimeMillis();
        content = String.format(avroFormat, name);
        data.setContent(content);
        amd = clientV3.groups().byGroupId(groupId).artifacts().byArtifactId(artifactId).put(data);
        Assertions.assertEquals(name, amd.getName());
    }

    @Test
    public void testJsonSchema() {
        String name = "schema-" + generateArtifactId();
        String description = "Automatic description generated at: " + System.currentTimeMillis();
        String content = String.format(jsonFormat, name, description);

        ArtifactTypeUtilProvider provider = factory.getArtifactTypeProvider(ArtifactType.JSON);
        ContentExtractor extractor = provider.getContentExtractor();

        ExtractedMetaData emd = extractor.extract(ContentHandle.create(content));
        Assertions.assertTrue(extractor.isExtracted(emd));
        Assertions.assertEquals(name, emd.getName());
        Assertions.assertEquals(description, emd.getDescription());
    }

    @Test
    public void testJsonSchemaClient() throws Exception {
        String artifactId = generateArtifactId();

        String name = "schema-" + generateArtifactId();
        String description = "Automatic description generated at: " + System.currentTimeMillis();
        String content = String.format(jsonFormat, name, description);

        ArtifactContent data = new ArtifactContent();
        data.setContent(content);
        ArtifactMetaData amd = clientV3.groups().byGroupId(groupId).artifacts().post(data, config -> {
            config.headers.add("X-Registry-ArtifactId", artifactId);
            config.headers.add("X-Registry-ArtifactType", ArtifactType.JSON);
        });

        Assertions.assertEquals(name, amd.getName());

        // test update

        name = "schema-" + generateArtifactId();
        content = String.format(jsonFormat, name, description);
        data.setContent(content);
        amd = clientV3.groups().byGroupId(groupId).artifacts().byArtifactId(artifactId).put(data);

        Assertions.assertEquals(name, amd.getName());
    }

    @Test
    public void testOpenApi() {
        String name = "api-" + generateArtifactId();
        String description = "Automatic description generated at: " + System.currentTimeMillis();
        String content = String.format(openapiFormat, name, description);

        ArtifactTypeUtilProvider provider = factory.getArtifactTypeProvider(ArtifactType.OPENAPI);
        ContentExtractor extractor = provider.getContentExtractor();

        ExtractedMetaData emd = extractor.extract(ContentHandle.create(content));
        Assertions.assertTrue(extractor.isExtracted(emd));
        Assertions.assertEquals(name, emd.getName());
        Assertions.assertEquals(description, emd.getDescription());
    }

    @Test
    public void testOpenApiClient() throws Exception {
        String artifactId = generateArtifactId();

        String name = "api-" + generateArtifactId();
        String description = "Automatic description generated at: " + System.currentTimeMillis();
        String content = String.format(openapiFormat, name, description);

        ArtifactContent data = new ArtifactContent();
        data.setContent(content);
        ArtifactMetaData amd = clientV3.groups().byGroupId(groupId).artifacts().post(data, config -> {
            config.headers.add("X-Registry-ArtifactId", artifactId);
            config.headers.add("X-Registry-ArtifactType", ArtifactType.OPENAPI);
        });

        Assertions.assertEquals(name, amd.getName());

        // test update

        name = "api-" + generateArtifactId();
        content = String.format(openapiFormat, name, description);
        data.setContent(content);
        amd = clientV3.groups().byGroupId(groupId).artifacts().byArtifactId(artifactId).put(data);

        Assertions.assertEquals(name, amd.getName());
    }

    @Test
    public void testAsyncApi() {
        String name = "api-" + generateArtifactId();
        String description = "Automatic description generated at: " + System.currentTimeMillis();
        String content = String.format(asyncapiFormat, name, description);

        ArtifactTypeUtilProvider provider = factory.getArtifactTypeProvider(ArtifactType.ASYNCAPI);
        ContentExtractor extractor = provider.getContentExtractor();

        ExtractedMetaData emd = extractor.extract(ContentHandle.create(content));
        Assertions.assertTrue(extractor.isExtracted(emd));
        Assertions.assertEquals(name, emd.getName());
        Assertions.assertEquals(description, emd.getDescription());
    }

    @Test
    public void testAsyncApiClient() throws Exception {
        String artifactId = generateArtifactId();

        String name = "api-" + generateArtifactId();
        String description = "Automatic description generated at: " + System.currentTimeMillis();
        String content = String.format(asyncapiFormat, name, description);

        ArtifactContent data = new ArtifactContent();
        data.setContent(content);
        ArtifactMetaData amd = clientV3.groups().byGroupId(groupId).artifacts().post(data, config -> {
            config.headers.add("X-Registry-ArtifactId", artifactId);
            config.headers.add("X-Registry-ArtifactType", ArtifactType.ASYNCAPI);
        });

        Assertions.assertEquals(name, amd.getName());

        // test update

        name = "api-" + generateArtifactId();
        content = String.format(asyncapiFormat, name, description);
        data.setContent(content);
        amd = clientV3.groups().byGroupId(groupId).artifacts().byArtifactId(artifactId).put(data);

        Assertions.assertEquals(name, amd.getName());
    }

    @Test
    public void testWsdl() {
        String content = wsdlFormat;

        ArtifactTypeUtilProvider provider = factory.getArtifactTypeProvider(ArtifactType.WSDL);
        ContentExtractor extractor = provider.getContentExtractor();

        ExtractedMetaData emd = extractor.extract(ContentHandle.create(content));
        Assertions.assertTrue(extractor.isExtracted(emd));
        Assertions.assertEquals("StockQuote", emd.getName());
        Assertions.assertNull(emd.getDescription());
    }

    @Test
    public void testWsdlClient() throws Exception {
        String artifactId = generateArtifactId();

        String content = wsdlFormat;

        ArtifactContent data = new ArtifactContent();
        data.setContent(content);
        ArtifactMetaData amd = clientV3.groups().byGroupId(groupId).artifacts().post(data, config -> {
            config.headers.add("X-Registry-ArtifactId", artifactId);
            config.headers.add("X-Registry-ArtifactType", ArtifactType.WSDL);
        });

        Assertions.assertEquals("StockQuote", amd.getName());
        Assertions.assertNull(amd.getDescription());
    }

    @Test
    public void testXsd() {
        String content = xsdFormat;

        ArtifactTypeUtilProvider provider = factory.getArtifactTypeProvider(ArtifactType.XSD);
        ContentExtractor extractor = provider.getContentExtractor();

        ExtractedMetaData emd = extractor.extract(ContentHandle.create(content));
        Assertions.assertTrue(extractor.isExtracted(emd));
        Assertions.assertEquals("http://tempuri.org/PurchaseOrderSchema.xsd", emd.getName());
        Assertions.assertNull(emd.getDescription());
    }

    @Test
    public void testXsdClient() throws Exception {
        String artifactId = generateArtifactId();

        String content = xsdFormat;

        ArtifactContent data = new ArtifactContent();
        data.setContent(content);
        ArtifactMetaData amd = clientV3.groups().byGroupId(groupId).artifacts().post(data, config -> {
            config.headers.add("X-Registry-ArtifactId", artifactId);
            config.headers.add("X-Registry-ArtifactType", ArtifactType.XSD);
        });
        Assertions.assertEquals("http://tempuri.org/PurchaseOrderSchema.xsd", amd.getName());
        Assertions.assertNull(amd.getDescription());
    }
}
