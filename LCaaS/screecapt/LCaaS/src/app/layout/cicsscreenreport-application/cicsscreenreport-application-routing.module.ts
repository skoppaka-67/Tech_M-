import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CicsScreenAppComponent } from './cicsscreenreport-application.component';

const routes: Routes = [
    {
        path: '', component: CicsScreenAppComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class CicsScreenAppRoutingModule {
}
