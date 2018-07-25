package com.lodoss.di.modules;

import com.lodoss.mobile_ui.MainActivity;
import com.lodoss.mobile_ui.auth.AuthActivity;

import dagger.Module;
import dagger.android.ContributesAndroidInjector;

@Module
abstract public class ActivityInjectorModule {

    @ActivityScope
    @ContributesAndroidInjector(modules = AuthModule.class)
    protected abstract AuthActivity contributeAuthActivity();

    @ActivityScope
    @ContributesAndroidInjector
    protected abstract MainActivity contributeMainActivity();

}
