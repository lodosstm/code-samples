package com.lodoss.proj.domain.interactors

import com.lodoss.proj.domain.executors.PostExecutionThread
import com.lodoss.proj.domain.executors.ThreadExecutor
import com.orhanobut.logger.Logger
import io.reactivex.Single
import io.reactivex.disposables.CompositeDisposable
import io.reactivex.disposables.Disposable
import io.reactivex.observers.DisposableSingleObserver
import io.reactivex.schedulers.Schedulers

abstract class SingleUseCase<T, in Params> protected constructor(
        private val threadExecutor: ThreadExecutor,
        private val postExecutionThread: PostExecutionThread) {

    private val disposables = CompositeDisposable()

    protected abstract fun buildUseCaseObservable(params: Params? = null): Single<T>

    open fun execute(singleObserver: DisposableSingleObserver<T>, params: Params? = null) {
        val single = this.buildUseCaseObservable(params)
                .subscribeOn(Schedulers.from(threadExecutor))
                .observeOn(postExecutionThread.scheduler) as Single<T>
        addDisposable(single.subscribeWith(singleObserver))
    }

    open fun execute(onSuccess: (result: T) -> Unit, params: Params? = null) {
        execute (object : DisposableSingleObserver<T>() {
            override fun onSuccess(t: T)  = onSuccess(t)

            override fun onError(e: Throwable) = Logger.e(e, e.message!!)
        }, params)
    }

    fun dispose() {
        if (!disposables.isDisposed) disposables.dispose()
    }

    private fun addDisposable(disposable: Disposable) {
        disposables.add(disposable)
    }

}