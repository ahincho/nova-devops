// Minimal, dependency-free project whose ONLY purpose is running the
// `dependencyCheckUpdate` task (update-only, no analysis) to build/refresh
// the shared NVD mirror consumed read-only by every Nova Java repo's
// reusable-owasp-check.yml (see nvd-mirror-update.yml).
//
// This is intentionally NOT wired into any Nova library's build - it lives
// here so the centralized update job has zero coupling to any one repo's
// dependency tree, checkstyle config, etc.
//
// The plugin version MUST stay in sync with the version used by
// reusable-owasp-check.yml's consumers (currently 12.2.2) so the H2/Lucene
// data format the update writes here is guaranteed compatible with what the
// analyze step reads.
plugins {
    id("org.owasp.dependencycheck") version "12.2.2"
}

dependencyCheck {
    nvd.apiKey = System.getenv("NVD_API_KEY") ?: ""
    // Where dependencyCheckUpdate writes the H2 database + Lucene index.
    // Defaults to the same path reusable-owasp-check.yml caches/restores,
    // but is overridable so the workflow can point it at a workspace-local
    // staging directory before zipping it up for the release asset.
    data.directory = System.getenv("NVD_DATA_DIRECTORY")
        ?: "${System.getProperty("user.home")}/.gradle/dependency-check-data"
}
