import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CICSXrefAppComponent } from './cicsxref-application.component';

const routes: Routes = [
    {
        path: '',
        component: CICSXrefAppComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class CICSXrefAppRoutingModule {}
