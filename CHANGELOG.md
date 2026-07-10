# Changelog

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
