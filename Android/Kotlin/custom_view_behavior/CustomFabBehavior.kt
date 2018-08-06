package team.lodoss.kotlin_sample

import android.content.Context
import android.support.design.widget.AppBarLayout
import android.support.design.widget.CoordinatorLayout
import android.support.design.widget.FloatingActionButton
import android.util.AttributeSet
import android.view.View


class CustomFabBehavior(
        context: Context?,
        attrs: AttributeSet?) : CoordinatorLayout.Behavior<FloatingActionButton>(context, attrs) {

    override fun layoutDependsOn(
            parent: CoordinatorLayout?,
            child: FloatingActionButton?,
            dependency: View?) = dependency is AppBarLayout

    override fun onDependentViewChanged(parent: CoordinatorLayout?, child: FloatingActionButton?, dependency: View?): Boolean {
        if (child == null || dependency == null) {
            return false
        }

        val appBarLayout = dependency as AppBarLayout
        val range = appBarLayout.totalScrollRange
        val factor = -appBarLayout.y / range

        child.scaleX = factor
        child.scaleY = factor

        child.x = (dependency.width - child.width - child.paddingRight) * factor

        return true
    }

}