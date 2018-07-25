package com.lodoss.di.modules.screens;

import com.lodoss.di.scopes.ActivityScope;
import com.lodoss.di.scopes.FragmentScope;
import com.lodoss.mobile_ui.auth.AuthActivity;
import com.lodoss.mobile_ui.auth.LoginFragment;
import com.lodoss.mobile_ui.auth.RegistrationFragment;
import com.lodoss.mobile_ui.auth.RestorePasswordFragment;
import com.lodoss.presentation.authentication.AuthView;
import com.lodoss.presentation.authentication.LoginContract;
import com.lodoss.presentation.authentication.LoginPresenter;
import com.lodoss.presentation.authentication.RestoreContract;
import com.lodoss.presentation.authentication.RestorePresenter;
import com.lodoss.presentation.authentication.SignUpContract;
import com.lodoss.presentation.authentication.SignUpPresenter;

import dagger.Binds;
import dagger.Module;
import dagger.android.ContributesAndroidInjector;

@Module
public abstract class AuthModule {

    // ------- Auth activity

    @Binds
    @ActivityScope
    protected abstract AuthView bindView(AuthActivity view);

    // ------- Sign in screen
    @Binds
    @FragmentScope
    protected abstract LoginContract.Presenter bindLoginPresenter(LoginPresenter presenter);

    @Binds
    @FragmentScope
    protected abstract LoginContract.Navigator bindNavigator(AuthActivity navigator);

    @FragmentScope
    @ContributesAndroidInjector
    protected abstract LoginFragment contributeLoginFragment();

    // ------- Restore password screen
    @FragmentScope
    @ContributesAndroidInjector
    protected abstract RestorePasswordFragment contributeRestorePasswordFragment();

    @Binds
    @FragmentScope
    protected abstract RestoreContract.Presenter bindRestorePresenter(RestorePresenter presenter);

    @Binds
    @FragmentScope
    protected abstract RestoreContract.Navigator bindRestoreNavigator(AuthActivity navigator);

    // ------- Sign up screen
    @FragmentScope
    @ContributesAndroidInjector
    protected abstract RegistrationFragment contributeRegistrationFragment();

    @Binds
    @FragmentScope
    protected abstract SignUpContract.Presenter bindSignUpPresenter(SignUpPresenter presenter);

    @Binds
    @FragmentScope
    protected abstract SignUpContract.Navigator bindSignUpNavigator(AuthActivity navigator);

}
