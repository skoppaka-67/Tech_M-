import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { FormAppComponent } from './form-application.component';

const routes: Routes = [
    {
        path: '', component: FormAppComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class FormAppRoutingModule {
}
