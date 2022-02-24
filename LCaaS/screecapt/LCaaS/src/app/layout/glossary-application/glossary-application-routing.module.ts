import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { GlossaryAppComponent } from './glossary-application.component';

const routes: Routes = [
    {
        path: '', component: GlossaryAppComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class GlossaryAppRoutingModule { }
