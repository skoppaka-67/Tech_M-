import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { XrefApplicationComponent } from './x-ref-application.component';

const routes: Routes = [
    {
        path: '',
        component: XrefApplicationComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class XrefApplicaitonRoutingModule {}
