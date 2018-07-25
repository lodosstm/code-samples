# Java based samples

## Database (db)
This folder contains classes to work with a local database. We use native [Room library](https://developer.android.com/topic/libraries/architecture/room) as an SQLite provider with RxJava.

### Files

* [BaseDao.java](db/BaseDao.java)
* [StepEntity.java](db/StepEntity.java)
* [StepNumberConverter.java](db/StepNumberConverter.java)
* [StepsDao.java](db/StepsDao.java)
* [PeopleStep.java](db/PeopleStep.java)

## Dependency injection (di)
This folder contains an implementation of the dependency injection pattern by [Dagger 2 library](https://google.github.io/dagger/).
For example [AuthModule.java](di/AuthModule.java) provides dependencies for MVP layer. All contract implementations has a protected modifier and this module is a single factory for building new dependencies.

### Files

* [ApplicationComponent.java](di/ApplicationComponent.java)
* [ApplicationModule.java](di/ApplicationModule.java)
* [ActivityInjectorModule.java](di/ActivityInjectorModule.java)
* [ActivityScope.java](di/ActivityScope.java)
* [FragmentScope.java](di/FragmentScope.java)
* [AuthModule.java](di/AuthModule.java)

## Mvp
This folder contains an implementation of the MVP architecture for Android project

### Files

* [BaseView.java](mvp/BaseView.java)
* [BasePresenter.java](mvp/BasePresenter.java)
* [StepListContract.java](mvp/StepListContract.java)
* [StepListPresenter.java](mvp/StepListPresenter.java)
* [StepListItemFragment.java](mvp/StepListItemFragment.java)

## Network
This folder contains an implementation of the REST based code. We use [Retrofit library](http://square.github.io/retrofit/) for http interaction.


### Files

* [InterceptorHeader.java](network/InterceptorHeader.java)
* [NetworkModule.java](network/NetworkModule.java)
* [RequestStep.java](network/RequestStep.java)
* [ResponseStep.java](network/ResponseStep.java)
* [RestApi.java](network/RestApi.java)