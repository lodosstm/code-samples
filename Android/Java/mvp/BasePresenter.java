package com.lodoss.sample_java.presentation;

public class BasePresenter<V extends BaseView, Navigator> {

    protected V mView;
    protected Navigator mNavigator;

    protected BasePresenter(V view, Navigator navigator) {
        mView = view;
        mNavigator = navigator;
    }

    public void onStart() {}

    public void onStop() {}

}
