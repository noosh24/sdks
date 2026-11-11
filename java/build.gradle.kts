plugins {
    `java-library`
    `maven-publish`
    signing
}

repositories {
    mavenCentral()
}

dependencies {
    api(platform("tools.jackson:jackson-bom:3.3.0"))
    api("tools.jackson.core:jackson-databind")
    api("org.jspecify:jspecify:1.0.1")

    testImplementation(platform("org.junit:junit-bom:6.1.3"))
    testImplementation("org.junit.jupiter:junit-jupiter")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

java {
    withSourcesJar()
    withJavadocJar()
}

tasks.withType<JavaCompile>().configureEach {
    options.release = 21
    options.encoding = "UTF-8"
    options.compilerArgs.addAll(listOf("-Xlint:all,-serial,-processing", "-Werror"))
}

tasks.withType<Javadoc>().configureEach {
    (options as StandardJavadocDocletOptions).apply {
        encoding = "UTF-8"
        addStringOption("Xdoclint:all,-missing", "-quiet")
    }
}

tasks.jar {
    manifest {
        attributes(
            "Automatic-Module-Name" to "com.noosh24.openapi",
            "Implementation-Title" to project.name,
            "Implementation-Version" to project.version,
        )
    }
}

tasks.test {
    useJUnitPlatform()
    testLogging {
        events("failed")
        exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL
    }
}

publishing {
    publications {
        create<MavenPublication>("maven") {
            artifactId = "noosh24-open-api"
            from(components["java"])
            pom {
                name = "Noosh24 Open API"
                description = "Official Java client for the Noosh24 Open API"
                url = "https://developer.noosh24.com"
                licenses {
                    license {
                        name = "MIT License"
                        url = "https://opensource.org/license/mit"
                    }
                }
                developers {
                    developer {
                        id = "noosh24"
                        name = "Noosh24"
                        url = "https://noosh24.com"
                    }
                }
                scm {
                    url = "https://github.com/noosh24/sdks/tree/main/java"
                    connection = "scm:git:https://github.com/noosh24/sdks.git"
                    developerConnection = "scm:git:ssh://git@github.com/noosh24/sdks.git"
                }
            }
        }
    }
    repositories {
        maven {
            name = "staging"
            url = uri(layout.buildDirectory.dir("staging-deploy"))
        }
    }
}

signing {
    val signingKey = providers.environmentVariable("SIGNING_KEY").orNull
    val signingPassword = providers.environmentVariable("SIGNING_PASSWORD").orNull
    if (signingKey != null) {
        useInMemoryPgpKeys(signingKey, signingPassword)
    }
    setRequired { gradle.taskGraph.allTasks.any { it is PublishToMavenRepository } }
    sign(publishing.publications["maven"])
}
