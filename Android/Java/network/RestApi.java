package com.lodoss.data.remote.rest;

import com.lodoss.data.remote.models.step.RequestStep;
import com.lodoss.data.remote.models.step.ResponseStep;

import java.util.List;

import io.reactivex.Completable;
import io.reactivex.Single;
import okhttp3.ResponseBody;
import retrofit2.Response;
import retrofit2.http.Body;
import retrofit2.http.Field;
import retrofit2.http.FormUrlEncoded;
import retrofit2.http.GET;
import retrofit2.http.Header;
import retrofit2.http.POST;
import retrofit2.http.PUT;
import retrofit2.http.Query;

public interface RestApi {

    /*
    * Some routes
    */

    // --------------------------------------  Steps
    @GET("/api/step ")
    Single<List<ResponseStep>> getSteps(@Header("accessToken") String accessToken);

    @POST("/api/step")
    Completable createSteps(
            @Header("accessToken") String accessToken,
            @Body List<RequestStep> steps);

    @PUT("/api/step")
    Completable updateSteps(
            @Header("accessToken") String accessToken,
            @Body List<RequestStep> steps);

}
