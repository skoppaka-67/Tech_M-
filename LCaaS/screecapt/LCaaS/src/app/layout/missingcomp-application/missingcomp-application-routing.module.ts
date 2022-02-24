import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { MissingcompAppComponent } from './missingcomp-application.component';

const routes: Routes = [
    {
        path: '',
        component: MissingcompAppComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class MissingcompAppRoutingModule {}
