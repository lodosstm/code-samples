package com.lodoss.di.modules;

import com.lodoss.BuildConfig;
import com.lodoss.data.remote.WebApi;
import com.lodoss.data.remote.interceptor.InterceptorHeader;
import com.lodoss.data.remote.rest.RestApi;

import java.util.concurrent.TimeUnit;

import javax.inject.Singleton;

import dagger.Module;
import dagger.Provides;
import okhttp3.OkHttpClient;
import okhttp3.logging.HttpLoggingInterceptor;
import retrofit2.Retrofit;
import retrofit2.adapter.rxjava2.RxJava2CallAdapterFactory;
import retrofit2.converter.gson.GsonConverterFactory;

@Module
public class NetworkModule {

    @Singleton
    @Provides
    protected OkHttpClient provideOkHttpClient(InterceptorError interceptorError) {
        HttpLoggingInterceptor logging = new HttpLoggingInterceptor();
        logging.setLevel(BuildConfig.DEBUG ?
                HttpLoggingInterceptor.Level.BODY :
                HttpLoggingInterceptor.Level.NONE);

        return new OkHttpClient.Builder()
                .readTimeout(30, TimeUnit.SECONDS)
                .connectTimeout(30, TimeUnit.SECONDS)
                .writeTimeout(30, TimeUnit.SECONDS)
                .addInterceptor(logging)
                .addInterceptor(new InterceptorHeader()
                .build();
    }

    @Singleton
    @Provides
    protected RestApi provideRetrofit(OkHttpClient okHttpClient) {
        return new Retrofit.Builder()
                .baseUrl(BuildConfig.BASE_URL)
                .client(okHttpClient)
                .addConverterFactory(GsonConverterFactory.create())
                .addCallAdapterFactory(RxJava2CallAdapterFactory.create())
                .build()
                .create(RestApi.class);
    }

}
