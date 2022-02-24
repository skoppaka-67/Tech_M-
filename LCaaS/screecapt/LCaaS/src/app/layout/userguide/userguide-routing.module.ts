import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { UserGuideComponent } from './userguide.component';

const routes: Routes = [
    {
        path: '',
        component: UserGuideComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class UserGuideRoutingModule {}
