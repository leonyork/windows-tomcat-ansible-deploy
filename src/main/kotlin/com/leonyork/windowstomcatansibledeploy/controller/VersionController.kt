package com.leonyork.windowstomcatansibledeploy.controller

import org.springframework.web.bind.annotation.*
import org.springframework.boot.info.BuildProperties

@RestController
class VersionController(private val buildProperties: BuildProperties) {

    @GetMapping("/version")
    fun greeting() = """${buildProperties.getVersion()}"""

}