import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { GlossaryComponent } from './glossary.component';

const routes: Routes = [
    {
        path: '', component: GlossaryComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class GlossaryRoutingModule { }
