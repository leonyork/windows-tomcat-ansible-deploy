import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    // https://mvnrepository.com/artifact/org.springframework.boot/spring-boot
    id("org.springframework.boot") version "2.3.5.RELEASE"
    // https://mvnrepository.com/artifact/io.spring.dependency-management/io.spring.dependency-management.gradle.plugin
    id("io.spring.dependency-management") version "1.0.10.RELEASE"
    war
    kotlin("jvm") version "1.3.70"
    kotlin("plugin.spring") version "1.3.70"
}

group = "com.leonyork"
version = System.getenv("WINDOWS_TOMCAT_ANSIBLE_DEPLOY_VERSION") ?: "SNAPSHOT"
java.sourceCompatibility = JavaVersion.VERSION_13

repositories {
    mavenCentral()
}

springBoot {
    buildInfo()
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin")
    implementation("org.jetbrains.kotlin:kotlin-reflect")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
    providedRuntime("org.springframework.boot:spring-boot-starter-tomcat")
    testImplementation("org.springframework.boot:spring-boot-starter-test") {
        exclude(group = "org.junit.vintage", module = "junit-vintage-engine")
    }
    testImplementation("org.hamcrest:hamcrest-all:1.3")
    testImplementation("org.exparity:hamcrest-date:2.0.7")
}

tasks.withType<Test> {
    useJUnitPlatform()
}

tasks.withType<KotlinCompile> {
    kotlinOptions {
        freeCompilerArgs = listOf("-Xjsr305=strict")
        jvmTarget = "12"
    }
}

tasks.register("printProjectAndVersion") {
    doLast {
        println("""build/libs/${rootProject.name}-${rootProject.version}.war""")
    }
}
