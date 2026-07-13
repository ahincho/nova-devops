# Changelog

## [1.1.0](https://github.com/ahincho/nova-devops/compare/nova-devops-v1.0.0...nova-devops-v1.1.0) (2026-07-13)


### Features

* **ci:** add 3 composite actions (nova-validate-build, nova-gather-facts, nova-publish-aggregator) ([95bc786](https://github.com/ahincho/nova-devops/commit/95bc7860ed037e1aaca82714ca2a80c1049b7c8f))
* **ci:** add 3 reusable workflows and 3 composite actions (NOVA-SEMVER-05-08) ([98da16b](https://github.com/ahincho/nova-devops/commit/98da16b594e880c00c8c30e869d7f3386e977fff))
* **ci:** add 6 multi-registry publish workflows (NOVA-SEMVER-09-12) ([aa7692c](https://github.com/ahincho/nova-devops/commit/aa7692c1c467f40ffa6e56d4b5c7db689242de18))
* **ci:** add centralized NVD mirror update workflow ([372a923](https://github.com/ahincho/nova-devops/commit/372a92335cc01d73479e6e372f7ab11eae2a6948))
* **ci:** add gradle/actions/setup-gradle for Remote Build Cache (NOVA-SEMVER-25) ([27fb98e](https://github.com/ahincho/nova-devops/commit/27fb98e41de8f89f45c22f1ad01a8214b45bea1b))
* **ci:** add release-please + tag-based publish flow (NOVA-SEMVER-13) ([688e5d2](https://github.com/ahincho/nova-devops/commit/688e5d23acc623cdb4bf15a7a190b9c99c2101fd))
* cross-repo GitHub Packages reads for Maven (NOVA_PACKAGES_READ_TOKEN) ([c197563](https://github.com/ahincho/nova-devops/commit/c19756379d5497a60c319700e75686e4195ce861))
* Reusable Workflows for Maven and Gradle Libraries ([4dce447](https://github.com/ahincho/nova-devops/commit/4dce447efcd0dab3bf7667da16a7705a521890f8))
* **workflows:** add build-matrix, owasp-check, sbom workflows (NOVA-SEMVER-19,20,21) ([4c21681](https://github.com/ahincho/nova-devops/commit/4c216816f6f76b28f5b72a24c53bc46e9f5f834e))
* **workflows:** migrate 4 reusable workflows to use composite actions (NOVA-SEMVER-27) ([97ee86b](https://github.com/ahincho/nova-devops/commit/97ee86b56ba432d25482953fb21a1d7a99a9e713))


### Bug Fixes

* **actions:** remove invalid vars context read inside nova-publish-aggregator ([bc60bda](https://github.com/ahincho/nova-devops/commit/bc60bda3832552b34c120730d53a0a4680f846a2))
* **actions:** support pom.xml (XML) version extraction in nova-gather-facts ([de91101](https://github.com/ahincho/nova-devops/commit/de91101b38feec13214555c12dc9a2b2e208ec52))
* **ci:** add chmod +x gradlew to all Gradle reusable workflows ([a742bd5](https://github.com/ahincho/nova-devops/commit/a742bd5958e1681ea2af8d873f34d43801cdf3fe))
* **ci:** add chmod +x gradlew to reusable-release-publish workflow ([5663961](https://github.com/ahincho/nova-devops/commit/566396108e19eb10cc40b984212b93c7a27ba37e))
* **ci:** correct bash syntax bug in nova-validate-build + add release-please config for nova-devops ([f1ba816](https://github.com/ahincho/nova-devops/commit/f1ba816eb9cf513228a2f36262c77f0afac8377d))
* **ci:** decouple OWASP NVD cache from build files, consume centralized mirror ([56fc254](https://github.com/ahincho/nova-devops/commit/56fc254fe01422d11f50de37b23669067095ec60))
* **ci:** disable irrelevant OWASP analyzers for Maven repos (Tier 4) ([436d4db](https://github.com/ahincho/nova-devops/commit/436d4db39677446e77b2e6ed5a29839fef07281d))
* **ci:** drop invalid gradle-version pin from nvd-mirror-update.yml ([44883df](https://github.com/ahincho/nova-devops/commit/44883dfb8b8f962354738f9c6b0b34bbb5fa7267))
* **ci:** make SonarCloud analysis tolerant to missing SONAR_TOKEN ([927c985](https://github.com/ahincho/nova-devops/commit/927c985851eb19938daa4e3d5ce4e735704a7597))
* **ci:** migrate reusable-release-please.yml to release-please-action@v4 inputs ([1950b5e](https://github.com/ahincho/nova-devops/commit/1950b5ea5b481b4363de192915eb542db2a79520))
* **ci:** pin composite actions to [@main](https://github.com/main) instead of non-existent [@v1](https://github.com/v1) tag ([ed036bb](https://github.com/ahincho/nova-devops/commit/ed036bb788b3db228db718c352beda33d5d76188))
* **ci:** remove continue-on-error on OWASP step now that NVD_API_KEY is configured ([5981d5e](https://github.com/ahincho/nova-devops/commit/5981d5ee59486054be63f5ade24160d49fbc84a4))
* **ci:** remove id-token write permission from release-please workflow ([6007066](https://github.com/ahincho/nova-devops/commit/6007066d752bee95695ee40c14f192aa5f8aa931))
* **ci:** stop passing release-type to release-please-action ([cf5d285](https://github.com/ahincho/nova-devops/commit/cf5d2850719d34243c5db553c5ededbca9396fb4))
* **ci:** use PAT fallback for release-please to enable tag-triggered workflows ([e20e0d7](https://github.com/ahincho/nova-devops/commit/e20e0d70f7594e6cd76db694ce13edc658ef2584))
* reusable-build-gradle.yml should not run checkstyleTest ([14f91f2](https://github.com/ahincho/nova-devops/commit/14f91f2b3822edb3a8c032652a7abe9aa87da58b))
* reusable-owasp-check.yml NVD_API_KEY secret was never wired up ([227b89a](https://github.com/ahincho/nova-devops/commit/227b89a20278ec46075b2e6073ef7153bcfe52c9))
* reuse NOVA_RELEASE_PAT as fallback for cross-repo package reads (bug B) ([af26feb](https://github.com/ahincho/nova-devops/commit/af26feb91dce4d694a8ce3af1c77346c9b299dc6))
* use 2 distinct server ids for Maven cross-repo reads ([1557ec2](https://github.com/ahincho/nova-devops/commit/1557ec2653f02184dc665a92403926d2d0ce87e0))
* **workflows:** move owasp continue-on-error to step level ([5ad3565](https://github.com/ahincho/nova-devops/commit/5ad3565fa58393aae7a539a1df6fa37a5739dd6d))
* **workflows:** OWASP/CycloneDX Gradle plugins do not read -P properties ([65e1d0a](https://github.com/ahincho/nova-devops/commit/65e1d0a5924fbaa7de9ded66bff2ba52dc1b35dc))
* **workflows:** rename reserved GITHUB_TOKEN secret to GH_TOKEN in 5 reusable workflows ([e59fceb](https://github.com/ahincho/nova-devops/commit/e59fceb2fe83194004563d6af30d8cce0b2570d0))

## 1.0.0 (2026-07-10)


### Features

* **ci:** add 3 composite actions (nova-validate-build, nova-gather-facts, nova-publish-aggregator) ([95bc786](https://github.com/ahincho/nova-devops/commit/95bc7860ed037e1aaca82714ca2a80c1049b7c8f))
* **ci:** add 3 reusable workflows and 3 composite actions (NOVA-SEMVER-05-08) ([98da16b](https://github.com/ahincho/nova-devops/commit/98da16b594e880c00c8c30e869d7f3386e977fff))
* **ci:** add 6 multi-registry publish workflows (NOVA-SEMVER-09-12) ([aa7692c](https://github.com/ahincho/nova-devops/commit/aa7692c1c467f40ffa6e56d4b5c7db689242de18))
* **ci:** add gradle/actions/setup-gradle for Remote Build Cache (NOVA-SEMVER-25) ([27fb98e](https://github.com/ahincho/nova-devops/commit/27fb98e41de8f89f45c22f1ad01a8214b45bea1b))
* **ci:** add release-please + tag-based publish flow (NOVA-SEMVER-13) ([688e5d2](https://github.com/ahincho/nova-devops/commit/688e5d23acc623cdb4bf15a7a190b9c99c2101fd))
* **workflows:** add build-matrix, owasp-check, sbom workflows (NOVA-SEMVER-19,20,21) ([4c21681](https://github.com/ahincho/nova-devops/commit/4c216816f6f76b28f5b72a24c53bc46e9f5f834e))
* **workflows:** migrate 4 reusable workflows to use composite actions (NOVA-SEMVER-27) ([97ee86b](https://github.com/ahincho/nova-devops/commit/97ee86b56ba432d25482953fb21a1d7a99a9e713))


### Bug Fixes

* **ci:** add chmod +x gradlew to all Gradle reusable workflows ([a742bd5](https://github.com/ahincho/nova-devops/commit/a742bd5958e1681ea2af8d873f34d43801cdf3fe))
* **ci:** add chmod +x gradlew to reusable-release-publish workflow ([5663961](https://github.com/ahincho/nova-devops/commit/566396108e19eb10cc40b984212b93c7a27ba37e))
* **ci:** correct bash syntax bug in nova-validate-build + add release-please config for nova-devops ([f1ba816](https://github.com/ahincho/nova-devops/commit/f1ba816eb9cf513228a2f36262c77f0afac8377d))
* **ci:** make SonarCloud analysis tolerant to missing SONAR_TOKEN ([927c985](https://github.com/ahincho/nova-devops/commit/927c985851eb19938daa4e3d5ce4e735704a7597))
* **ci:** pin composite actions to [@main](https://github.com/main) instead of non-existent [@v1](https://github.com/v1) tag ([ed036bb](https://github.com/ahincho/nova-devops/commit/ed036bb788b3db228db718c352beda33d5d76188))
* **ci:** remove id-token write permission from release-please workflow ([6007066](https://github.com/ahincho/nova-devops/commit/6007066d752bee95695ee40c14f192aa5f8aa931))
