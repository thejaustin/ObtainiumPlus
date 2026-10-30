buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.2.20")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// KGP 2.4+ removed support for Kotlin language versions < 2.0. Override all
// subprojects so legacy plugins (sentry_flutter, android_file_picker, etc.)
// that declare languageVersion 1.6/1.8 in their own build.gradle don't fail.
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
            apiVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    if (name == "cronet_http") {
        // Always embed Cronet so no build (including F-Droid) depends on Play
        // Services (ported from upstream #3200).
        val defines = (findProperty("dart-defines") as String?)
            ?.split(',')
            ?.filter { it.isNotBlank() }
            .orEmpty()
        val embedded = java.util.Base64.getEncoder()
            .encodeToString("cronetHttpNoPlay=true".toByteArray())
        extensions.extraProperties["dart-defines"] =
            (defines + embedded).joinToString(",")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
