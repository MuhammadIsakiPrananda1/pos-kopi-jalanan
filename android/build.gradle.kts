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

subprojects {
    val fixSubproject = {
        val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (android != null) {
            if (android.namespace == null && project.name == "blue_thermal_printer") {
                android.namespace = "id.kakzaki.blue_thermal_printer"
            }
            if (project.name == "blue_thermal_printer") {
                android.compileSdkVersion(35)
            }
        }
    }
    
    if (project.state.executed) {
        fixSubproject()
    } else {
        project.afterEvaluate { fixSubproject() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
