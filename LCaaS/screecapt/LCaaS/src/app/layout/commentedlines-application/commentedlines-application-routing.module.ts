import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CommentedLinesAppComponent } from './commentedlines-application.component';

const routes: Routes = [
    {
        path: '', component: CommentedLinesAppComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class CommentedLinesAppRoutingModule { }
