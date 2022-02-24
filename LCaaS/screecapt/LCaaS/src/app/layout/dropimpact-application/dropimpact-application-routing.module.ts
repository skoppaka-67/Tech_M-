import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { DropImpactAppComponent } from './dropimpact-application.component';

const routes: Routes = [
    {
        path: '', component: DropImpactAppComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class DropImpactAppRoutingModule { }
