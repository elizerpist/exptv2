package com.fluvi.app.lockscreen.material

import java.security.MessageDigest
import org.junit.Assert.*
import org.junit.Test

class KeyguardOrbProgramSelectorTest {
    private val selector = KeyguardOrbProgramSelector("dualTide", false)
    private val body = "half4 main(float2 p) { return half4(0); }\n"
    private fun artifact(): KeyguardShaderArtifact {
        val hash = MessageDigest.getInstance("SHA-256").digest(body.toByteArray())
            .joinToString("") { "%02x".format(it.toInt() and 0xff) }
        val header = "// generated-from=shaders/dashboard_header_field.frag\n" +
            "// source-sha256=${KeyguardMaterialProfile.SOURCE_SHADER_HASH}\n" +
            "// effect-id=dualTide\n// variant=plain\n"
        return KeyguardShaderArtifact("dualTide", false, header + body,
            KeyguardHeaderShader.Metadata(KeyguardMaterialProfile.SOURCE_SHADER_HASH, hash, "9"))
    }

    @Test fun exactSourceAndMetadataAreAccepted() {
        assertTrue(selector.accepts(artifact()))
    }
    @Test fun changedBodyAndMismatchedMetadataAreRejected() {
        val source = artifact()
        assertFalse(selector.accepts(source.copy(source = source.source + " ")))
        assertFalse(selector.accepts(source.copy(metadata = source.metadata.copy(adapterVersion = "10"))))
        assertFalse(selector.accepts(source.copy(metadata = source.metadata.copy(sourceShaderHash = "wrong"))))
        assertFalse(selector.accepts(source.copy(metadata = source.metadata.copy(generatedAgslHash = "wrong"))))
    }
    @Test fun changedVariantEffectOrHeaderIsRejected() {
        val source = artifact()
        assertFalse(KeyguardOrbProgramSelector("dualTide", true).accepts(source))
        assertFalse(KeyguardOrbProgramSelector("magneticMembrane", false).accepts(source))
        assertFalse(selector.accepts(source.copy(source = source.source.replace("variant=plain", "variant=portal"))))
    }
}
