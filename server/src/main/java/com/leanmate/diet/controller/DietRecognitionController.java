package com.leanmate.diet.controller;

import com.leanmate.common.error.ErrorCode;
import com.leanmate.common.exception.BusinessException;
import com.leanmate.common.response.ApiResponse;
import com.leanmate.common.security.CurrentUserContext;
import com.leanmate.diet.application.DietRecognitionApplicationService;
import com.leanmate.diet.domain.MealType;
import com.leanmate.diet.dto.PhotoRecognitionRequest;
import com.leanmate.diet.dto.RecognitionTaskResponse;
import com.leanmate.diet.dto.TextRecognitionRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.http.MediaType;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@Validated
@RestController
@RequestMapping("/v1/diet/recognitions")
public class DietRecognitionController {

    private final DietRecognitionApplicationService dietRecognitionApplicationService;

    public DietRecognitionController(DietRecognitionApplicationService dietRecognitionApplicationService) {
        this.dietRecognitionApplicationService = dietRecognitionApplicationService;
    }

    @PostMapping(value = "/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<RecognitionTaskResponse> createPhotoTask(
            @RequestParam("image") MultipartFile image,
            @RequestParam("mealType") String mealType,
            @RequestParam(required = false) LocalDate mealDate,
            @RequestParam(required = false) @Size(max = 500) String note
    ) {
        PhotoRecognitionRequest request = new PhotoRecognitionRequest(
                image.getOriginalFilename(),
                image.getContentType(),
                image.getSize(),
                parseMealType(mealType),
                mealDate,
                note);
        return ApiResponse.success(dietRecognitionApplicationService.createPhotoTask(
                CurrentUserContext.getRequired().userId(),
                request));
    }

    @PostMapping("/text")
    public ApiResponse<RecognitionTaskResponse> createTextTask(
            @Valid @RequestBody TextRecognitionRequest request
    ) {
        return ApiResponse.success(dietRecognitionApplicationService.createTextTask(
                CurrentUserContext.getRequired().userId(),
                request));
    }

    @GetMapping("/{taskId}")
    public ApiResponse<RecognitionTaskResponse> getTask(@PathVariable UUID taskId) {
        return ApiResponse.success(dietRecognitionApplicationService.getTask(
                CurrentUserContext.getRequired().userId(),
                taskId));
    }

    private MealType parseMealType(String value) {
        try {
            return MealType.fromValue(value);
        } catch (IllegalArgumentException exception) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "mealType 无效");
        }
    }
}
