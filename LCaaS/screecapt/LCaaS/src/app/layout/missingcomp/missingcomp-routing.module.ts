import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { MissingcompComponent } from './missingcomp.component';

const routes: Routes = [
    {
        path: '',
        component: MissingcompComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class MissingcompRoutingModule {}
