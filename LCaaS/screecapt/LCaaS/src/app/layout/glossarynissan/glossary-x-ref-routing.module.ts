import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { GlossaryXrefComponent } from './glossary-x-ref.component';

const routes: Routes = [
    {
        path: '',
        component: GlossaryXrefComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class GlosssaryXrefRoutingModule {}
