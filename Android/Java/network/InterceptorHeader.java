package com.lodoss.data.remote.interceptor;

import java.io.IOException;

import okhttp3.Interceptor;
import okhttp3.Request;
import okhttp3.Response;

public class InterceptorHeader implements Interceptor {

    @Override
    public Response intercept(Chain chain) throws IOException {
        Request request = chain.request();
        Request newRequest = request.newBuilder()
                .addHeader("Content-Type", "application/json")
                .addHeader("Accept", "application/json")
                .addHeader("application-type", "REST")
                .addHeader("Connection", "close")
                .build();

        return chain.proceed(newRequest);
    }

}
