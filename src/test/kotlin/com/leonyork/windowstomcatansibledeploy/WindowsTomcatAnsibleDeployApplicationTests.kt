package com.leonyork.windowstomcatansibledeploy

import org.assertj.core.api.Assertions.assertThat
import org.exparity.hamcrest.date.ZonedDateTimeMatchers.sameOrBefore
import org.hamcrest.MatcherAssert.assertThat
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment.RANDOM_PORT
import org.springframework.boot.test.web.client.TestRestTemplate
import org.springframework.boot.test.web.client.getForEntity
import org.springframework.http.HttpStatus.OK
import java.time.ZonedDateTime.now
import java.time.ZonedDateTime.parse

@SpringBootTest(webEnvironment = RANDOM_PORT)
class WindowsTomcatAnsibleDeployApplicationTests(@Autowired val restTemplate: TestRestTemplate) {
    @Test
    fun `Calling index returns status code 200 with a date and time before now`() {
        val entity = restTemplate.getForEntity<String>("/")
        assertThat(entity.statusCode).isEqualTo(OK)
        assertThat(parse(entity.body), sameOrBefore(now()))
    }
}
