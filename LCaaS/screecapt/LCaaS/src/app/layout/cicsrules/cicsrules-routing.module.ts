import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CicsRulesComponent } from './cicsrules.component';

const routes: Routes = [
    {
        path: '', component: CicsRulesComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class CicsRulesRoutingModule { }
