package com.leonyork.windowstomcatansibledeploy

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class WindowsTomcatAnsibleDeployApplication

fun main(args: Array<String>) {
	runApplication<WindowsTomcatAnsibleDeployApplication>(*args)
}
