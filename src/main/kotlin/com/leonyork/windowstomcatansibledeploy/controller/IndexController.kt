package com.leonyork.windowstomcatansibledeploy.controller

import org.springframework.web.bind.annotation.*
import org.springframework.boot.info.BuildProperties

@RestController
class IndexController(private val buildProperties: BuildProperties) {

    @GetMapping("/")
    fun greeting() = """${buildProperties.getTime()}"""

}