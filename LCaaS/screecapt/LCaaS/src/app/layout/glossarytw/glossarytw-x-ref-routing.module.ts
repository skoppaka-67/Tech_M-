import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { GlossaryTWXrefComponent } from './glossarytw-x-ref.component';

const routes: Routes = [
    {
        path: '',
        component: GlossaryTWXrefComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class GlosssaryTWXrefRoutingModule {}
