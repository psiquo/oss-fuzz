import com.code_intelligence.jazzer.api.FuzzedDataProvider;

import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.ByteArrayInputStream;
import java.io.StringWriter;
import java.io.IOException;

import org.apache.commons.configuration2.JSONConfiguration;
import org.apache.commons.configuration2.ex.ConfigurationException;

public class JSONConfigurationWriteFuzzer {
    public static void fuzzerTestOneInput(FuzzedDataProvider data) {
        // Create helper objects from fuzzer data
        final boolean useReader = data.consumeBoolean();
        final byte[] byteArray = data.consumeBytes(Integer.MAX_VALUE);

        // Create needed objects
        JSONConfiguration jsonConfig = new JSONConfiguration();
        InputStream inputStream = new ByteArrayInputStream(byteArray);
        InputStreamReader reader;
        StringWriter writer = new StringWriter();

        try {
            if (useReader) {
                reader = new InputStreamReader(inputStream);
                jsonConfig.read(reader);
            } else {
                jsonConfig.read(inputStream);
            }
            jsonConfig.write(writer);
        } catch (IOException | ConfigurationException ignored) {
            // expected Exceptions get ignored
        }
    }
}
