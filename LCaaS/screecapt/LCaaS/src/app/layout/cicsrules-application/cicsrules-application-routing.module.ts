import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CicsRulesAppComponent } from './cicsrules-application.component';

const routes: Routes = [
    {
        path: '', component: CicsRulesAppComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class CicsRulesAppRoutingModule { }
