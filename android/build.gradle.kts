allprojects {
    repositories {
        google()
        mavenCentral()
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

// `flutter_pos_printer_platform_image_3` (and friends) hardcode a low
// `compileSdkVersion` (31) in their own android/{build.gradle}, so AGP's
// `checkReleaseAarMetadata` fails: their transitive androidx dependencies
// (e.g. androidx.window.extensions.core) require compiling against API 33+.
// Compile every android module against Flutter's default SDK (36) instead.
// AGP 7 modules expose `setCompileSdkVersion`, AGP 8 modules `setCompileSdk`;
// both are found via the generated setter name since the extension type (and
// the AGP it came from) isn't on the root project's buildscript classpath.
fun setPluginCompileSdk(p: Project) {
    val androidExt = p.extensions.findByName("android") ?: return
    val method = androidExt::class.java.methods.firstOrNull { candidate ->
        candidate.parameterCount == 1 &&
            (candidate.name == "setCompileSdk" || candidate.name == "setCompileSdkVersion") &&
            (candidate.parameterTypes[0] == Integer.TYPE ||
                candidate.parameterTypes[0] == Integer::class.java)
    } ?: return
    println("BREWLINE: bump ${p.name} ${method.name}(${method.parameterTypes[0]}) to 36")
    method.invoke(androidExt, Integer.valueOf(36))
}
// Register the override in each subproject's own afterEvaluate (registered here,
// first, so it runs BEFORE AGP's internal afterEvaluate that reads compileSdk).
subprojects {
    if (state.executed) {
        setPluginCompileSdk(project)
    } else {
        project.afterEvaluate {
            setPluginCompileSdk(project)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
