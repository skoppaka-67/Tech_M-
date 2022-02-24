import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { BsComponentExtComponent } from './programprocessflow-external.component';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

const routes: Routes = [
    {
        path: '',
        component: BsComponentExtComponent
    }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class BsComponentExtRoutingModule {}
