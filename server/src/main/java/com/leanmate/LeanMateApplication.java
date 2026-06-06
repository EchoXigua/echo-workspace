package com.leanmate;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class LeanMateApplication {

    public static void main(String[] args) {
        SpringApplication.run(LeanMateApplication.class, args);
    }
}
