import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CICSXrefComponent } from './cics-x-ref.component';

const routes: Routes = [
    {
        path: '',
        component: CICSXrefComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class CICSXrefRoutingModule {}
