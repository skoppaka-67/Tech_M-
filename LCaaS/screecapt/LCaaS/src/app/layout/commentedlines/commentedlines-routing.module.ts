import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CommentedLinesComponent } from './commentedlines.component';

const routes: Routes = [
    {
        path: '', component: CommentedLinesComponent
    }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class CommentedLinesRoutingModule { }
