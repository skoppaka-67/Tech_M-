import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { XrefComponent } from './x-ref.component';

const routes: Routes = [
    {
        path: '',
        component: XrefComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class XrefRoutingModule {}
