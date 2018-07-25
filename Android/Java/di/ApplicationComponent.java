package com.lodoss.di.components;

import com.lodoss.mobile_ui.SampleApplication;

import javax.inject.Singleton;

import dagger.BindsInstance;
import dagger.Component;
import dagger.android.AndroidInjectionModule;

@Singleton
@Component (modules = {
        ApplicationModule.class,
        AndroidInjectionModule.class,
        ActivityInjectorModule.class
})
public interface ApplicationComponent {

    @Component.Builder
    interface Builder {
        @BindsInstance
        Builder application(SampleApplication application);

        ApplicationComponent build();
    }

    void inject(SampleApplication application);

}
