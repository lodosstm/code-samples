package com.lodoss.di.modules;

import android.arch.persistence.room.Room;
import android.arch.persistence.room.RoomDatabase;
import android.content.Context;
import android.content.SharedPreferences;

import com.lodoss.BuildConfig;
import com.lodoss.data.JobExecutor;
import com.lodoss.data.local.Database;
import com.lodoss.domain.executor.ThreadExecutor;
import com.lodoss.domain.executor.ThreadPostExecutor;
import com.lodoss.mobile_ui.SampleApplication;
import com.lodoss.mobile_ui.UiThread;

import javax.inject.Singleton;

import dagger.Module;
import dagger.Provides;

@Module(includes = {
        ApiModule.class,
        DaoModule.class
})
public class ApplicationModule {

    @Singleton
    @Provides
    protected Context provideAppContext(SampleApplication sampleApplication) {
        return sampleApplication.getApplicationContext();
    }

    @Singleton
    @Provides
    protected ThreadExecutor provideThreadExecutor(JobExecutor jobExecutor) {
        return jobExecutor;
    }

    @Singleton
    @Provides
    protected ThreadPostExecutor provideThreadPostExecutor(UiThread uiThread) {
        return uiThread;
    }

    @Singleton
    @Provides
    protected SharedPreferences provideSharedPreferences(Context context) {
        return context.getSharedPreferences(BuildConfig.PREFERENCES_FILE, Context.MODE_PRIVATE);
    }

    @Singleton
    @Provides
    protected Database provideDatabase(Context context) {
        return Room.databaseBuilder(context, Database.class, Database.NAME)
                .build();
    }

}
