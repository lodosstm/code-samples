package team.lodoss.kotlin_sample

import android.support.v7.app.AppCompatActivity
import android.os.Bundle
import android.support.design.widget.Snackbar
import kotlinx.android.synthetic.main.activity_main.*

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        fab.setOnClickListener {
            Snackbar.make(
                coordinator_layout,
                "Sample app",
                Snackbar.LENGTH_SHORT).show()
        }
    }
}
